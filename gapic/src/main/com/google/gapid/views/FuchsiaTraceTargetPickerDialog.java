/*
 * Copyright (C) 2022 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.google.gapid.views;

import static com.google.gapid.widgets.Widgets.createComposite;
import java.util.ArrayList;
import java.util.List;
import static java.util.stream.StreamSupport.stream;

import com.google.common.base.CharMatcher;
import com.google.common.base.Splitter;
import com.google.common.collect.Maps;
import com.google.gapid.image.Images;
import com.google.gapid.models.Analytics.View;
import com.google.gapid.models.Component;
import com.google.gapid.models.ComponentFilter;
import com.google.gapid.models.Models;
import com.google.gapid.models.TraceTargets;
import com.google.gapid.proto.service.Service;
import com.google.gapid.proto.service.Service.ClientAction;
import com.google.gapid.util.Loadable;
import com.google.gapid.util.Loadable.Message;
import com.google.gapid.util.Messages;
import com.google.gapid.widgets.DialogBase;
import com.google.gapid.widgets.LoadablePanel;
import com.google.gapid.widgets.Widgets;

import org.eclipse.jface.dialogs.IDialogConstants;
import org.eclipse.jface.viewers.ArrayContentProvider;
import org.eclipse.jface.viewers.ColumnLabelProvider;
import org.eclipse.jface.viewers.ISelectionChangedListener;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.jface.viewers.SelectionChangedEvent;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.jface.viewers.TableViewerColumn;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.KeyAdapter;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Text;


/**
 * Dialog to allow the user to pick a trace target for tracing.
 */
public class FuchsiaTraceTargetPickerDialog extends DialogBase implements TraceTargets.Listener {
  private static final int INITIAL_HEIGHT = 600;
  private static final CharMatcher SEARCH_SEPARATOR = CharMatcher.anyOf("/\\");
  private static final Splitter SEARCH_SPLITTER = Splitter.on(SEARCH_SEPARATOR)
      .trimResults()
      .omitEmptyStrings();

  private final Models models;
  private final Widgets widgets;
  protected final TraceTargets targets;

  private Loadable.Message lastLoadError;
  private TraceTargets.Node selected;

  TableViewer tableViewer;
  Table componentTable;
  ComponentFilter filter;

  Button ok;

  public FuchsiaTraceTargetPickerDialog(Shell shell, Models models, TraceTargets targets, Widgets widgets) {
    super(shell, widgets.theme);
    this.models = models;
    this.targets = targets;
    this.widgets = widgets;
  }

  public TraceTargets.Node getSelected() {
    return selected;
  }

  @Override
  public int open() {
    try {
      return super.open();
    } finally {
      System.out.println("open - finally");
    }
    /*
    models.analytics.postInteraction(View.Trace, ClientAction.ShowActivityPicker);

    lastLoadError = null;
    targets.load();
    targets.addListener(this);
    try {
      return super.open();
    } finally {
      targets.removeListener(this);
    }
    */
  }

  @Override
  public String getTitle() {
    return Messages.SELECT_COMPONENT;
  }

  @Override
  public void create() {
    super.create();
  }

  @Override
  protected Point getInitialSize() {
    Point size = super.getInitialSize();
    size.y = INITIAL_HEIGHT;
    return size;
  }

  @Override
  protected Control createDialogArea(Composite parent) {
    System.out.println("\ncreateDialogArea (Fuchsia)");
    Composite area = (Composite)super.createDialogArea(parent);

    Composite container = createComposite(area, new GridLayout(1, false));
    container.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, true));

    Text searchText =
        new Text(container, SWT.SINGLE | SWT.SEARCH | SWT.ICON_SEARCH | SWT.ICON_CANCEL);
    searchText.setLayoutData(new GridData(SWT.FILL, SWT.TOP, true, false));

    tableViewer = new TableViewer(container, SWT.SINGLE | SWT.H_SCROLL
            | SWT.V_SCROLL | SWT.FULL_SELECTION | SWT.BORDER);
    tableViewer.setContentProvider(ArrayContentProvider.getInstance());

    filter = new ComponentFilter();
    tableViewer.addFilter(filter);

    searchText.addKeyListener(new KeyAdapter() {
      public void keyReleased(KeyEvent ke) {
        filter.setSearchText(searchText.getText());
        tableViewer.refresh();
      }
    });

    GridData gridData = new GridData();
    gridData.horizontalAlignment = GridData.FILL;
    gridData.verticalAlignment = GridData.FILL;
    gridData.grabExcessHorizontalSpace = true;
    gridData.grabExcessVerticalSpace = true;
    tableViewer.getControl().setLayoutData(gridData);

    componentTable = tableViewer.getTable();
    componentTable.setLayoutData(gridData);
    componentTable.setLinesVisible(true);
    componentTable.setHeaderVisible(true);

    List<Component> components = new ArrayList<Component>();
    components.add(new Component("234441", "vkproto"));
    components.add(new Component("254441", "vkcube"));
    components.add(new Component("274441", "vkother"));

    tableViewer.setInput(components);

    // create a column for the global ID
    TableViewerColumn globalID = new TableViewerColumn(tableViewer, SWT.NONE);
    globalID.getColumn().setWidth(120);
    globalID.getColumn().setText("Global ID");
    globalID.setLabelProvider(new ColumnLabelProvider() {
      @Override
      public String getText(Object item) {
        Component component = (Component) item;
        return component.getId();
      }
    });

    // create a column for the component name.
    TableViewerColumn componentName = new TableViewerColumn(tableViewer, SWT.NONE);
    componentName.getColumn().setWidth(200);
    componentName.getColumn().setText("Component Name");
    componentName.setLabelProvider(new ColumnLabelProvider() {
      @Override
      public String getText(Object item) {
        Component component = (Component) item;
        return component.getName();
      }
    });

    tableViewer.addSelectionChangedListener(new ISelectionChangedListener() {
      @Override
      public void selectionChanged(SelectionChangedEvent event) {
        IStructuredSelection selection = tableViewer.getStructuredSelection();
        Component item = (Component) selection.getFirstElement();
        System.out.println("New selection: " + item.toString());
      }
    });

    tableViewer.refresh();

    /*
    String[] titles = { "Global ID", "Component Name" };
        for (int i = 0; i < titles.length; i++) {
            TableColumn column = new TableColumn(componentTable, SWT.NONE);
            column.setText(titles[i]);
            componentTable.getColumn(i).pack();
        }

    String[] names = { "vkproto", "vkcube", "vkother" };
    String[] globalIDs = { "321996", "843551", "971276" };
        for (int i = 0 ; i< names.length ; i++){
            TableItem item = new TableItem(componentTable, SWT.NONE);
            item.setText (0, globalIDs[i]);
            item.setText (1, names[i]);
        }

    componentTable.addListener (SWT.SetData, new Listener () {
      public void handleEvent (Event event) {
          TableItem item = (TableItem) event.item;
          int index = componentTable.indexOf (item);
          item.setText ("\tItem " + index);
          System.out.println ("\t" + item.getText ());
      }
    });

    componentTable.addSelectionListener(new SelectionAdapter() {
      public void widgetSelected(SelectionEvent event) {
        System.out.println("\t" + event.toString() + " selected");
        TableItem item = (TableItem) event.item;
        String globalID = item.getText(0);
        String componentName = item.getText(1);
        System.out.println("\t" + globalID + "\t" + componentName + "\n");
        ok.setEnabled(true);
      }
    });
    */

    return area;
  }

  @Override
  protected void createButtonsForButtonBar(Composite parent) {
    ok = createButton(parent, IDialogConstants.OK_ID, IDialogConstants.OK_LABEL, true);
    createButton(parent, IDialogConstants.CANCEL_ID, IDialogConstants.CANCEL_LABEL, false);
    ok.setEnabled(false);
  }
}
